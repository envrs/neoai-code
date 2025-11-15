define([
    'base/js/namespace',
    'base/js/keyboard',
    'base/js/utils',
    'jquery',
    'module',
    'notebook/js/cell',
    'notebook/js/codecell',
    'notebook/js/completer',
    'require'
], (
    Jupyter,
    keyboard,
    utils,
    $,
    module,
    cell,
    codecell,
    completer,
    requirejs
) => {
    'use strict';

    const N_LINES_BEFORE = 50;
    const N_LINES_AFTER = 50;

    let assistActive;

    const config = {
        assist_active: true,
        options_limit: 10,
        assist_delay: 0,
        before_line_limit: -1,
        after_line_limit: -1,
        remote_server_url: '',
    };

    const logPrefix = `[${module.id}]`;
    const baseUrl = utils.get_body_data('baseUrl');
    const requestInfo = {
        "version": "1.0.7",
        "request": {
            "Autocomplete": {
                "filename": Jupyter.notebook.notebook_path.replace('.ipynb', '.py'),
                "before": "",
                "after": "",
                "region_includes_beginning": false,
                "region_includes_end": false,
                "max_num_results": config.options_limit,
            }
        }
    };

    const Cell = cell.Cell;
    const CodeCell = codecell.CodeCell;
    const Completer = completer.Completer;
    const keycodes = keyboard.keycodes;
    const specials = [
        keycodes.enter, keycodes.esc, keycodes.backspace, keycodes.tab,
        keycodes.up, keycodes.down, keycodes.left, keycodes.right,
        keycodes.shift, keycodes.ctrl, keycodes.alt, keycodes.meta,
        keycodes.capslock, keycodes.pageup, keycodes.pagedown,
        keycodes.end, keycodes.home, keycodes.insert, keycodes.delete,
        keycodes.numlock, keycodes.f1, keycodes.f2, keycodes.f3,
        keycodes.f4, keycodes.f5, keycodes.f6, keycodes.f7,
        keycodes.f8, keycodes.f9, keycodes.f10, keycodes.f11,
        keycodes.f12, keycodes.f13, keycodes.f14, keycodes.f15
    ];

    function loadCss(name) {
        $('<link/>').attr({
            type: 'text/css',
            rel: 'stylesheet',
            href: requirejs.toUrl(name)
        }).appendTo('head');
    }

    function onlyModifierEvent(event) {
        const key = keyboard.inv_keycodes[event.which];
        return (
            (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) &&
            (key === 'alt' || key === 'ctrl' || key === 'meta' || key === 'shift')
        );
    }

    function requestCompleterServer(requestData) {
        let serverUrl = config.remote_server_url || baseUrl;
        serverUrl = new URL('neoai', serverUrl.endsWith('/') ? serverUrl : `${serverUrl}/`).href;

        return $.get(serverUrl, { 'data': JSON.stringify(requestData) })
            .then(data => (typeof data === 'string' ? JSON.parse(data) : data))
            .fail(error => console.error(`${logPrefix} get error: `, error));
    }

    function isValidCodeLine(line) {
        // comment line is valid, since we want to get completions
        return line.length > 0 && line.charAt(0) !== '!';
    }

    // A Deep Completer which extends Completer
    const DeepCompleter = function (cell, events) {
        Completer.call(this, cell, events);
    };
    DeepCompleter.prototype = Object.create(Completer.prototype);
    DeepCompleter.prototype.constructor = DeepCompleter;

    DeepCompleter.prototype.finish_completing = function (msg) {
        const optionsLimit = config.options_limit;
        if (this.visible && $('#complete').length) {
            console.info(logPrefix, 'complete is visible, ignoring.');
            return;
        }

        const { editor, cell: currCell } = this;
        const cursor = editor.getCursor();
        
        const { before, after, region_includes_beginning, region_includes_end } = this.gather_context(currCell, cursor);

        this.before = before;
        this.after = after;

        requestInfo.request.Autocomplete.before = before.slice(-N_LINES_BEFORE).join("\n");
        requestInfo.request.Autocomplete.after = after.slice(0, N_LINES_AFTER).join("\n");
        requestInfo.request.Autocomplete.region_includes_beginning = region_includes_beginning;
        requestInfo.request.Autocomplete.region_includes_end = region_includes_end;

        this.complete = $('<div/>').addClass('completions complete-dropdown-content').attr('id', 'complete');
        $('body').append(this.complete);
        this.visible = true;
        this.start = editor.indexFromPos(cursor);
        this.complete.hide();

        requestCompleterServer(requestInfo).done(data => {
            if (!data || !data.results || data.results.length === 0) {
                this.close();
                return;
            }
            this.completions = data.results.slice(0, optionsLimit);
            const completionElements = this.completions.map(generateCompleteContainer);
            this.complete.append(completionElements);
            
            this.add_user_msg(data.user_message);
            this.set_location(data.old_prefix);
            this.add_keyevent_listeners();
        });
        return true;
    };
    
    DeepCompleter.prototype.gather_context = function(currCell, cursor) {
        const beforeLineLimit = config.before_line_limit > 0 ? config.before_line_limit : Infinity;
        const afterLineLimit = config.after_line_limit > 0 ? config.after_line_limit : Infinity;
        const currCellLines = currCell.get_text().split("\n");

        let before = [];
        let after = [];
        
        const currLine = currCellLines[cursor.line];
        if (isValidCodeLine(currLine)) {
            before.push(currLine.slice(0, cursor.ch));
            after.push(currLine.slice(cursor.ch));
        }

        // Before cursor in current cell
        for (let i = cursor.line - 1; i >= 0 && before.length < beforeLineLimit; i--) {
            if (isValidCodeLine(currCellLines[i])) before.push(currCellLines[i]);
        }
        let region_includes_beginning = cursor.line === 0;

        // After cursor in current cell
        for (let i = cursor.line + 1; i < currCellLines.length && after.length < afterLineLimit; i++) {
            if (isValidCodeLine(currCellLines[i])) after.push(currCellLines[i]);
        }
        let region_includes_end = cursor.line === currCellLines.length - 1;

        const cells = Jupyter.notebook.get_cells();
        const currCellIndex = cells.findIndex(c => c === currCell);

        // Look in cells before
        if (before.length < beforeLineLimit) {
            for (let i = currCellIndex - 1; i >= 0 && before.length < beforeLineLimit; i--) {
                const cellLines = cells[i].get_text().split("\n");
                for (let j = cellLines.length - 1; j >= 0 && before.length < beforeLineLimit; j--) {
                    if (isValidCodeLine(cellLines[j])) before.push(cellLines[j]);
                }
            }
            region_includes_beginning = currCellIndex === 0;
        }

        // Look in cells after
        if (after.length < afterLineLimit) {
            for (let i = currCellIndex + 1; i < cells.length && after.length < afterLineLimit; i++) {
                const cellLines = cells[i].get_text().split("\n");
                for (let j = 0; j < cellLines.length && after.length < afterLineLimit; j++) {
                    if (isValidCodeLine(cellLines[j])) after.push(cellLines[j]);
                }
            }
            region_includes_end = currCellIndex === cells.length - 1;
        }

        before.reverse();
        return { before, after, region_includes_beginning, region_includes_end };
    }

    DeepCompleter.prototype.add_user_msg = function (user_messages) {
        if (user_messages && user_messages.length > 0) {
            const msgElements = user_messages.map(msg =>
                $('<div/>').addClass('user-message').append($('<span/>').text(msg))
            );
            this.complete.append(msgElements);
        }
    };

    DeepCompleter.prototype.update = function () {
        if (!this.complete) return;

        const cursor = this.editor.getCursor();
        this.start = this.editor.indexFromPos(cursor);
        const currLineText = this.editor.getLine(cursor.line);
        
        this.before[this.before.length - 1] = currLineText.slice(0, cursor.ch);
        this.after[0] = currLineText.slice(cursor.ch);

        requestInfo.request.Autocomplete.before = this.before.slice(-N_LINES_BEFORE).join('\n');
        requestInfo.request.Autocomplete.after = this.after.slice(0, N_LINES_AFTER).join('\n');

        requestCompleterServer(requestInfo).done(data => {
            if (!data || !data.results || data.results.length === 0) {
                this.close();
                return;
            }

            const { results, user_message, old_prefix } = data;
            this.completions = results.slice(0, config.options_limit);

            const $complete = $('#complete');
            const $containers = $complete.find('.complete-container');
            
            // Update existing or add new completion elements
            this.completions.forEach((completion, i) => {
                if (i < $containers.length) {
                    $($containers[i]).find('.complete-word').text(completion.new_prefix);
                    $($containers[i]).find('.complete-detail').text(completion.detail);
                } else {
                    $complete.append(generateCompleteContainer(completion));
                }
            });

            // Remove surplus containers
            if ($containers.length > this.completions.length) {
                $containers.slice(this.completions.length).remove();
            }

            // Update user messages
            $complete.find('.user-message').remove();
            this.add_user_msg(user_message);

            this.set_location(old_prefix);
            this.editor.off('keydown', this._handle_keydown);
            this.editor.off('keyup', this._handle_keyup);
            this.add_keyevent_listeners();
        });
    };

    DeepCompleter.prototype.close = function () {
        this.done = true;
        $('#complete').remove();
        this.editor.off('keydown', this._handle_keydown);
        this.editor.off('keyup', this._handle_keyup);
        this.visible = false;
        this.completions = null;
        this.completeFrom = null;
        this.complete = null;
    };

    DeepCompleter.prototype.set_location = function (oldPrefix) {
        if (!this.complete) return;

        this.completeFrom = this.editor.posFromIndex(this.start);
        if (oldPrefix) {
            this.completeFrom.ch -= oldPrefix.length;
        }

        const pos = this.editor.cursorCoords(this.completeFrom);
        const cheight = this.complete.height();
        const wheight = $(window).height();
        const top = (pos.bottom + cheight + 5 > wheight) ? (pos.top - cheight - 4) : (pos.bottom + 1);

        this.complete.css({
            left: `${pos.left - 3}px`,
            top: `${top}px`,
            display: 'initial'
        });
    };

    DeepCompleter.prototype.add_keyevent_listeners = function () {
        const $options = $("#complete").find('.complete-container');
        const editor = this.editor;
        let currIndex = -1;

        this._handle_keydown = (comp, event) => {
            if (!$('#complete').length || !this.completions) return;

            this.isKeyupFired = false;
            const { up, tab, down, enter } = keycodes;

            if ([up, tab, down, enter].includes(event.keyCode)) {
                event.codemirrorIgnore = true;
                event._ipkmIgnore = true;
                event.preventDefault();

                if (event.keyCode === enter) {
                    this.close();
                    return;
                }

                const prevIndex = currIndex;
                if (event.keyCode === up) currIndex--;
                else currIndex++;

                if (currIndex < 0) currIndex = $options.length - 1;
                if (currIndex >= $options.length) currIndex = 0;

                $($options[currIndex]).css('background', 'lightblue');
                if (prevIndex !== -1) {
                    $($options[prevIndex]).css('background', '');
                }

                const completion = this.completions[currIndex];
                const end = editor.getCursor();
                if (completion.old_suffix) {
                    end.ch += completion.old_suffix.length;
                }
                const replacement = completion.new_prefix + completion.new_suffix;
                editor.replaceRange(replacement, this.completeFrom, end);
            } else if (!needUpdateComplete(event.keyCode)) {
                this.close();
            }
        };

        this._handle_keyup = (cmp, event) => {
            if (!this.isKeyupFired && !event.altKey && !event.ctrlKey && !event.metaKey && needUpdateComplete(event.keyCode)) {
                this.update();
                this.isKeyupFired = true;
            }
        };

        editor.on('keydown', this._handle_keydown);
        editor.on('keyup', this._handle_keyup);
    };

    function generateCompleteContainer(responseComplete) {
        return $('<div/>').addClass('complete-container')
            .append($('<div/>').addClass('complete-block complete-word').text(responseComplete.new_prefix))
            .append($('<div/>').addClass('complete-block complete-detail').text(responseComplete.detail));
    }

    const isAlphabeticKeyCode = (keyCode) => (keyCode >= 65 && keyCode <= 90);
    const isNumberKeyCode = (keyCode) => (keyCode >= 48 && keyCode <= 57) || (keyCode >= 96 && keyCode <= 105);
    const isOperatorKeyCode = (keyCode) => (keyCode >= 106 && keyCode <= 111) || (keyCode >= 186 && keyCode <= 192) || (keyCode >= 219 && keyCode <= 222);
    const needUpdateComplete = (keyCode) => isAlphabeticKeyCode(keyCode) || isNumberKeyCode(keyCode) || isOperatorKeyCode(keyCode);

    function patchCellKeyevent() {
        const origHandleCodemirrorKeyEvent = Cell.prototype.handle_codemirror_keyevent;
        Cell.prototype.handle_codemirror_keyevent = function (editor, event) {
            if (!this.base_completer) {
                this.base_completer = new Completer(this, this.events);
            }
            if (!this.deep_completer) {
                this.deep_completer = new DeepCompleter(this, this.events);
            }

            if (assistActive && !event.altKey && !event.metaKey && !event.ctrlKey &&
                (this instanceof CodeCell) && !onlyModifierEvent(event)) {
                this.tooltip.remove_and_cancel_tooltip();

                if (!editor.somethingSelected() && editor.getSelections().length <= 1 &&
                    !this.completer.visible && !specials.includes(event.keyCode)) {
                    
                    this.completer = (event.keyCode === keycodes.space && event.shiftKey)
                        ? this.base_completer
                        : this.deep_completer;
                    
                    if (this.completer === this.base_completer) event.preventDefault();

                    setTimeout(() => this.completer.startCompletion(), config.assist_delay);
                }
            }
            return origHandleCodemirrorKeyEvent.apply(this, arguments);
        };
    }

    function setAssistState(newState) {
        assistActive = newState;
        $('.assistant-toggle > .fa').toggleClass('fa-check', assistActive);
        console.log(`${logPrefix} continuous autocompletion ${assistActive ? 'on' : 'off'}`);
    }

    function toggleAutocompletion() {
        setAssistState(!assistActive);
    }

    function addMenuItem() {
        if ($('#help_menu').find('.assistant-toggle').length > 0) return;

        const menuItem = $('<li/>').insertAfter('#keyboard_shortcuts');
        const menuLink = $('<a/>').text('Jupyter NeoAi')
            .addClass('assistant-toggle')
            .attr('title', 'Provide continuous code autocompletion')
            .on('click', toggleAutocompletion)
            .appendTo(menuItem);
        $('<i/>').addClass('fa menu-icon pull-right').prependTo(menuLink);
    }

    function load_notebook_extension() {
        return Jupyter.notebook.config.loaded.then(() => {
            $.extend(true, config, Jupyter.notebook.config.data.jupyter_neoai);
            loadCss('./main.css');
        }, err => {
            console.warn(`${logPrefix} error loading config:`, err);
        }).then(() => {
            patchCellKeyevent();
            addMenuItem();
            setAssistState(config.assist_active);
        });
    }

    return {
        load_ipython_extension: load_notebook_extension,
        load_jupyter_extension: load_notebook_extension
    };
});
